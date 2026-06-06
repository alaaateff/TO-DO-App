FROM node:18-alpine
WORKDIR /docker-frontend
COPY package-lock.json package.json ./ 
RUN npm install
COPY src ./src
CMD ["npm" , "start"]
