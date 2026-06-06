FROM node:18-alpine
WORKDIR /docker-backend
COPY package-lock.json package.json ./
RUN npm install
COPY models ./models
COPY routes ./routes
COPY db.js ./
COPY index.js ./
CMD ["node" , "index.js"]
