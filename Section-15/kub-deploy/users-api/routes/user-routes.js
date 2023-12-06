const express = require("express");

const userActions = require("../controllers/user-actions");

const router = express.Router();

router.get("/", (req, res) => {
  res.send("<h1>Welcome to the Landing Page!</h1>");
});

router.post("/signup", userActions.createUser);

router.post("/login", userActions.verifyUser);

module.exports = router;
