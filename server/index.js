const jsonServer = require("json-server");
const express = require("express");
const cors      = require('cors');


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
server.use(cors());

server.use("/issue", issueRouter);
server.use("/redeem", redeemRouter);

server.use(middlewares);
server.use(router);

server.listen(3000, () => {
  console.log(`JSON Server is running at http://localhost:3000`);
});
