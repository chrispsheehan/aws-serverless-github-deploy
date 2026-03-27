function handler(event) {
  var request = event.request;
  var stripped = request.uri.replace(/^\/api/, '');
  request.uri = stripped === '' ? '/' : stripped;
  return request;
}
