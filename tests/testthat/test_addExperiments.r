context("addExperiments")

test_that("addProblem", {
  reg = makeTempExperimentRegistry(FALSE)
  prob = addProblem(reg = reg, "p1", data = iris, fun = function(job, data, ...) nrow(data))
  expect_is(prob, "Problem")
  expect_equal(prob$data, iris)
  expect_equal(prob$name, "p1")
  expect_function(prob$fun)
  expect_null(prob$seed)
  expect_file(file.path(reg$file.dir, "problems", "p1.rds"))

  prob = addProblem(reg = reg, "p2", fun = function(job, data) NULL, seed = 42)
  expect_is(prob, "Problem")
  expect_null(prob$data, NULL)
  expect_equal(prob$name, "p2")
  expect_function(prob$fun)
  expect_identical(prob$seed, 42L)
  expect_file(file.path(reg$file.dir, "problems", "p1.rds"))

  algo = addAlgorithm(reg = reg, "a1", fun = function(job, data, problem, ...) NULL)
  ids = addExperiments(list(p1 = data.table(), p2 = data.table()), algo.designs = list(a1 = data.table()), repls = 2, reg = reg)

  removeProblem(reg = reg, "p1")
  expect_set_equal(reg$problems, "p2")
  expect_false(file.exists(file.path(reg$file.dir, "problems", "p1.rds")))
  expect_set_equal(getJobDefs(reg = reg)$problem, "p2")
  checkTables(reg)
})

test_that("addAlgorithm", {
  reg = makeTempExperimentRegistry(FALSE)
  algo = addAlgorithm(reg = reg, "a1", fun = function(job, data, problem, ...) NULL)
  expect_is(algo, "Algorithm")
  expect_equal(algo$name, "a1")
  expect_function(algo$fun)
  expect_file(file.path(reg$file.dir, "algorithms", "a1.rds"))

  prob = addProblem(reg = reg, "p1", data = iris, fun = function(job, data) nrow(data))
  algo = addAlgorithm(reg = reg, "a2", fun = function(job, data, problem) NULL)
  ids = addExperiments(list(p1 = data.table()), algo.designs = list(a1 = data.table(), a2 = data.table()), repls = 2, reg = reg)

  removeAlgorithm(reg = reg, "a1")
  expect_set_equal(reg$algorithms, "a2")
  expect_false(file.exists(file.path(reg$file.dir, "algorithms", "a1.rds")))
  expect_set_equal(getJobDefs(reg = reg)$algorithm, "a2")
  checkTables(reg)
})

test_that("addExperiments handles parameters correctly", {
  reg = makeTempExperimentRegistry(FALSE)
  prob = addProblem(reg = reg, "p1", data = iris, fun = function(job, data, x, y, ...) stopifnot(is.numeric(x) && is.character(y)), seed = 42)
  algo = addAlgorithm(reg = reg, "a1", fun = function(job, data, problem, a, b, ...) { print(str(a)); stopifnot(is.list(a)) })
  prob.designs = list(p1 = data.table(x = 1:2, y = letters[1:2]))
  algo.designs = list(a1 = data.table(a = list(foo = 1, bar = iris)))
  repls = 1
  ids = addExperiments(prob.designs, algo.designs, repls = repls, reg = reg)
  silent({
    submitJobs(reg = reg, ids = chunkIds(reg = reg))
    waitForJobs(reg = reg)
  })
  expect_true(nrow(findError(reg = reg)) == 0)
})
