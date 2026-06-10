FROM node:18-alpine
WORKDIR /docker-frontend
ENV NODE_OPTIONS=--openssl-legacy-provider
COPY package-lock.json package.json ./ 
RUN npm install
COPY src ./src
COPY public ./public
CMD ["npm" , "start"]
