const jsonServer = require("json-server");
const express = require("express");
const http = require("http");
const url = require("url");
const cors = require("cors");

const server = jsonServer.create();
const router = jsonServer.router("db.json");
const middlewares = jsonServer.defaults();

const issueRouter = express.Router().get("/", (req, res) => {
  const { customer, point } = req.query;
  let getRewardState = router.db.getState().getRewardState;
  getRewardState.push({
    customer,
    point,
  });
  router.db.setState({ ...router.db.getState(), getRewardState });
  res.send(getRewardState);
});

const redeemRouter = express.Router().get("/", (req, res) => {
  const { voucher, point, customer } = req.query;
  let getRedemptionState = router.db.getState().getRedemptionState;
  getRedemptionState.push({ voucher, point, customer });
  router.db.setState({ ...router.db.getState(), getRedemptionState });
  res.send(getRedemptionState);
});

const vouchersRouter = express
  .Router()
  .post("/", (req, res) => {
    console.log(req.body, req.params);
    const { name, point } = req.body;
    let vouchers = router.db.getState().vouchers;
    vouchers.push({ name, point });
    router.db.setState({ ...router.db.getState(), vouchers });
    res.send({ name, point });
  })
  .get("/", (_, res) => res.send(router.db.getState().vouchers));
const getActualRequestDurationInMilliseconds = (start) => {
  const NS_PER_SEC = 1e9; // convert to nanoseconds
  const NS_TO_MS = 1e6; // convert to milliseconds
  const diff = process.hrtime(start);
  return (diff[0] * NS_PER_SEC + diff[1]) / NS_TO_MS;
};
let demoLogger = (req, res, next) => {
  let current_datetime = new Date();
  let formatted_date =
    current_datetime.getFullYear() +
    "-" +
    (current_datetime.getMonth() + 1) +
    "-" +
    current_datetime.getDate() +
    " " +
    current_datetime.getHours() +
    ":" +
    current_datetime.getMinutes() +
    ":" +
    current_datetime.getSeconds();
  let method = req.method;
  let url = req.url;
  let status = res.statusCode;
  const start = process.hrtime();
  const durationInMilliseconds = getActualRequestDurationInMilliseconds(start);
  let log = `[${formatted_date}] ${method}:${url} ${status} ${durationInMilliseconds.toLocaleString()} ms`;
  console.log(log);
  next();
};
server.use(cors());
server.use(express.urlencoded({ extended: true }));
server.use(express.json());

server.use(demoLogger);

server.use("/proxy/", async (request, response) => {
  var options = url.parse(`http://18.140.71.165:9998${request.url}`);
  options.headers = request.headers;
  options.method = request.method;
  options.agent = false;
  const connector = http.request(options, (res) =>
    res.pipe(response, { end: true })
  );
  request.pipe(connector, { end: true });
});

server.use("/issue", issueRouter);
server.use("/vouchers", vouchersRouter);
server.use("/redeem", redeemRouter);

server.use(middlewares);
server.use(router);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`JSON Server is running at http://localhost:${PORT}`);
});
