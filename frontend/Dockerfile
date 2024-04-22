FROM node:20-alpine

WORKDIR /app

COPY src/ /app/src
COPY public/ /app/public
COPY package.json /app/

RUN npm install

CMD ["npm", "start"]