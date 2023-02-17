ThisBuild / scalaVersion := "3.2.2"

lazy val root = (project in file("."))
  .settings(
    name := "github-analysis",
    libraryDependencies ++= Seq(
      "com.47deg" %% "github4s" % "0.32.0",
      "com.lihaoyi" %% "requests" % "0.8.0",
      "io.circe" %% "circe-parser" % "0.14.4",
      "org.scalameta" %% "munit" % "0.7.29" % Test
    )
  )
