lazy val root = (project in file("."))
  .settings(
    name := "github-analysis",
    scalaVersion := "3.3.4",
    libraryDependencies ++= Seq(
      "com.47deg" %% "github4s" % "0.33.2",
      "org.scalameta" %% "munit" % "1.0.3" % Test,
    )
  )
