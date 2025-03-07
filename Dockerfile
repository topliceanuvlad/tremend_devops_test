# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory to /app
WORKDIR /app

# Copy the dependencies file to the working directory
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code to the working directory
COPY calculator.py .

# Expose port 8080 for the application
EXPOSE 8080

# Command to run the application using gunicorn on port 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "calculator:app"]
