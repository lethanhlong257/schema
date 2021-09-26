export const searchService = {
  host: process.env.SEARCH_SERVICE_GRPC_HOST || '0.0.0.0',
  port: process.env.SEARCH_SERVICE_GRPC_PORT ||6000,
}