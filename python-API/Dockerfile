# Use a minimal base image
FROM python:3.13-slim AS base

# Set environment variables to prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set working directory
WORKDIR /app

# Install dependencies only in a separate stage to leverage Docker's caching
FROM base AS builder
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Final image with only necessary files
FROM base AS final
COPY --from=builder /root/.local /root/.local
ENV PATH="/root/.local/bin:$PATH"

# Copy application code
COPY . .

# Expose the FastAPI port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
