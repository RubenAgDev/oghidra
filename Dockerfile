# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code into the container at /app
COPY . .

# Make port 8081 available to the world outside this container (for ghidra_mcp_server.py)
EXPOSE 8081

# Default command can be to run the ghidra_mcp_server.py,
# or leave it as bash for more flexibility in development.
# For this setup, we'll make the extended API server the default.
# Users can use `docker-compose exec` for the CLI.
CMD ["python", "src/ghidra_mcp_server.py"]
