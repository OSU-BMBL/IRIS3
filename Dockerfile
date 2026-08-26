# IRIS3 CLI Docker Image
# Based on rocker/r-ver with Python and bioinformatics tools

FROM rocker/r-ver:4.4.0

LABEL maintainer="IRIS3 Team"
LABEL description="IRIS3: Integrated Cell-type-specific Regulon Inference Server"
LABEL version="2.0.0"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build tools
    build-essential \
    g++ \
    make \
    cmake \
    # OpenMP for QUBIC2
    libgomp1 \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # HDF5 for 10X data
    libhdf5-dev \
    # Required for R packages
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    # Seurat dependencies
    libgsl-dev \
    libblas-dev \
    liblapack-dev \
    libglpk-dev \
    # Bioinformatics tools
    bedtools \
    # MEME Suite dependencies
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libexpat1-dev \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    ghostscript \
    # Utilities
    wget \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv for Python package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
ENV UV_SYSTEM_PYTHON=1

# Install Bioconductor and required R packages (R 4.4 -> Bioconductor 3.19)
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org')" && \
    R -e "BiocManager::install(version = '3.19', ask = FALSE)"

# Ensure Matrix is at latest version (SeuratObject needs >= 1.6.4)
RUN R -e "install.packages('Matrix', repos='https://cloud.r-project.org')"

# Core R packages (excluding Seurat)
RUN R -e "install.packages(c('yaml', 'data.table', 'scales', 'tibble', 'dplyr', 'stringr', 'doParallel', 'magic', 'reshape2', 'rlist'), repos='https://cloud.r-project.org')"

# Install Seurat separately (large package with many dependencies)
RUN R -e "install.packages('Seurat', repos='https://cloud.r-project.org')" && \
    R -e "if (!require('Seurat')) stop('Seurat installation failed')"

# Bioconductor packages
RUN R -e "BiocManager::install(c( \
    'AUCell', \
    'BioQC', \
    'GSVA', \
    'ensembldb', \
    'AnnotationDbi' \
), ask = FALSE)"

# Organism-specific annotation packages (Human + Mouse only)
RUN R -e "BiocManager::install(c( \
    'org.Hs.eg.db', \
    'org.Mm.eg.db', \
    'BSgenome.Hsapiens.UCSC.hg38', \
    'BSgenome.Mmusculus.UCSC.mm10', \
    'TxDb.Hsapiens.UCSC.hg38.knownGene', \
    'TxDb.Mmusculus.UCSC.mm10.knownGene' \
), ask = FALSE)"

# Install MEME Suite (motif discovery)
ENV MEME_VERSION=5.5.5
RUN cd /tmp && \
    wget https://meme-suite.org/meme/meme-software/${MEME_VERSION}/meme-${MEME_VERSION}.tar.gz && \
    tar -xzf meme-${MEME_VERSION}.tar.gz && \
    cd meme-${MEME_VERSION} && \
    ./configure --prefix=/opt/meme --enable-build-libxml2 --enable-build-libxslt && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/meme-*

ENV PATH="/opt/meme/bin:${PATH}"

# Download JASPAR motif database for TOMTOM
RUN mkdir -p /opt/meme/db && \
    cd /opt/meme/db && \
    wget -q https://jaspar.elixir.no/download/data/2024/CORE/JASPAR2024_CORE_vertebrates_non-redundant_pfms_meme.txt && \
    wget -q https://jaspar.elixir.no/download/data/2024/CORE/JASPAR2024_CORE_non-redundant_pfms_meme.txt

ENV IRIS3_MOTIF_DB=/opt/meme/db/JASPAR2024_CORE_vertebrates_non-redundant_pfms_meme.txt

# Create app directory
WORKDIR /app

# Copy and compile QUBIC2
COPY program/qubic2 /app/tools/qubic2
RUN cd /app/tools/qubic2 && \
    make clean 2>/dev/null || true && \
    make && \
    chmod +x qubic

ENV PATH="/app/tools/qubic2:${PATH}"

# Copy R modules
COPY r_modules /app/r_modules

# Copy Python package and install with uv
COPY pyproject.toml uv.lock* README.md /app/
COPY iris3 /app/iris3
COPY config /app/config
RUN uv pip install -e .

# Copy example config
COPY config/example_config.yaml /app/config/

# Create directories for data
RUN mkdir -p /data /output

# Set environment variables for tool paths
ENV IRIS3_MEME_PATH=/opt/meme/bin
ENV IRIS3_QUBIC_PATH=/app/tools/qubic2
ENV IRIS3_R_MODULES=/app/r_modules

# Default command
ENTRYPOINT ["iris3"]
CMD ["--help"]
