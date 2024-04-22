FROM node:20-alpine

WORKDIR /backend

COPY index.js /backend/
COPY config.js /backend/
COPY package.json /backend/

RUN npm install

CMD ["npm", "start"]