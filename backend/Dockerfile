FROM node:21-alpine

WORKDIR /backend

COPY index.js /backend/
COPY package.json /backend/

RUN npm install

CMD ["npm", "start"]