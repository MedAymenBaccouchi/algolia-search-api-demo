FROM node:14.19.3-alpine3.16

# Authors
LABEL authors="Aymen Baccouchi"

# Create app directory
WORKDIR /app

# Copy package.json to handle dependencies
# and package-lock.json to ensure identical tree
COPY package.json package-lock.json /app/

# Install dependencies
RUN npm install

# Bundle app source
COPY . /app

# Expose container port
EXPOSE 3000

CMD ["npm", "start"]