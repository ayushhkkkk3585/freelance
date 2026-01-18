module.exports = {
  ...require('./auth.middleware'),
  validate: require('./validate.middleware'),
  upload: require('./upload.middleware'),
};
