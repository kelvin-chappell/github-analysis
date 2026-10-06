lazy val root = (project in file("."))
  .settings(
    name := "github-analysis",
    scalaVersion := "3.9.0",
    libraryDependencies ++= Seq(
      "com.47deg" %% "github4s" % "0.33.3",
      "org.scalameta" %% "munit" % "1.3.5" % Test
    ),
    // Scaladoc (via liqp) transitively pulls in vulnerable jackson-core versions
    dependencyOverrides ++= Seq(
      "com.fasterxml.jackson.core" % "jackson-core" % "2.21.7",
      "tools.jackson.core" % "jackson-core" % "3.1.7"
    )
  )
