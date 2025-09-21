"use strict";
const express = require("express");
const bodyParser = require("body-parser");
const jwt = require("express-jwt");

//COMENTARIO DE PRUEBA PIPELINE CORRECTO DEV PARA JS
const ZIPKIN_URL =
  process.env.ZIPKIN_URL || "http://127.0.0.1:9411/api/v2/spans";
const {
  Tracer,
  BatchRecorder,
  jsonEncoder: { JSON_V2 },
} = require("zipkin");
const CLSContext = require("zipkin-context-cls");
const { HttpLogger } = require("zipkin-transport-http");
const zipkinMiddleware =
  require("zipkin-instrumentation-express").expressMiddleware;

const logChannel = process.env.REDIS_CHANNEL || "log_channel";
const redisClient = require("redis").createClient({
  host: process.env.REDIS_HOST || "localhost",
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD,
  tls: {}, // Enable TLS for Azure Redis
  retry_strategy: function (options) {
    if (options.error && options.error.code === "ECONNREFUSED") {
      console.log("Redis connection refused, continuing without Redis");
      return new Error("The server refused the connection");
    }
    if (options.total_retry_time > 1000 * 60 * 60) {
      console.log("Redis retry time exhausted, continuing without Redis");
      return new Error("Retry time exhausted");
    }
    if (options.attempt > 10) {
      console.log(
        "reattemtping to connect to redis, attempt #" + options.attempt
      );
      return undefined;
    }
    return Math.min(options.attempt * 100, 2000);
  },
});

// Handle Redis errors gracefully
redisClient.on('error', function(err) {
  console.log('Redis client error: ' + err.message);
});

redisClient.on('connect', function() {
  console.log('Redis client connected');
});

redisClient.on('ready', function() {
  console.log('Redis client ready');
});
const port = process.env.TODO_API_PORT || 8082;
const jwtSecret = process.env.JWT_SECRET || "foo";

console.log('DEBUG: todos-api JWT_SECRET:', jwtSecret);
console.log('DEBUG: todos-api JWT_SECRET length:', jwtSecret.length);

const app = express();

// tracing
const ctxImpl = new CLSContext("zipkin");
const recorder = new BatchRecorder({
  logger: new HttpLogger({
    endpoint: ZIPKIN_URL,
    jsonEncoder: JSON_V2,
  }),
});
const localServiceName = "todos-api";
const tracer = new Tracer({ ctxImpl, recorder, localServiceName });

// Health check endpoint (before JWT middleware to avoid authentication)
app.get("/health", function (req, res) {
  res.status(200).json({
    status: "UP",
    service: "todos-api",
    timestamp: Date.now(),
  });
});

app.use(jwt({
  secret: jwtSecret,
  requestProperty: 'user'
}));
app.use(zipkinMiddleware({ tracer }));
app.use(function (err, req, res, next) {
  console.log('DEBUG: JWT Error:', err.name, err.message);
  console.log('DEBUG: JWT Error details:', err);
  if (err.name === "UnauthorizedError") {
    res.status(401).send({ message: "invalid token" });
  } else {
    next(err);
  }
});
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

const routes = require("./routes");
routes(app, { tracer, redisClient, logChannel });

app.listen(port, function () {
  console.log("todo list RESTful API server started on: " + port);
});
