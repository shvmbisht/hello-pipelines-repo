#
# ---- Build ----
FROM node:14.15.2-alpine AS build
ARG WORK_DIR=/var/www/node
WORKDIR ${WORK_DIR}
# accept npm token to access private npm registry from build arg
ARG NPM_AUTH_TOKEN
# copy ALL except ignored by .dockerignore
COPY . .
# install ALL node_modules, including 'devDependencies'
RUN yarn install --frozen-lockfile
# build
RUN yarn build
# prune production package
RUN rm -rf node_modules && yarn install --production
# use node-prune to remove unused files (doc,*.md,images) from node_modules
RUN wget https://gobinaries.com/tj/node-prune && sh node-prune && node-prune

#
# ---- Release ----
FROM node:14.15.2-alpine AS release
ARG WORK_DIR=/var/www/node
WORKDIR ${WORK_DIR}
# copy the rest of files
COPY --from=build ${WORK_DIR}/node_modules ./node_modules
COPY --from=build ${WORK_DIR}/dist ./dist
COPY --from=build ${WORK_DIR}/config ./config
COPY --from=build ${WORK_DIR}/i18n ./i18n
COPY nest-cli.json yarn.lock package*.json ./
# define CMD
CMD npm run start:prod