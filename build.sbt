ThisBuild / scalaVersion := "3.2.2"

lazy val root = (project in file("."))
  .settings(
    name := "github-analysis",
    libraryDependencies ++= Seq(
      "com.47deg" %% "github4s" % "0.32.0",
      "org.scalameta" %% "munit" % "1.0.1" % Test
    )
  )
