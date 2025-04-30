lazy val root = (project in file("."))
  .settings(
    name := "github-analysis",
    scalaVersion := "3.3.5",
    libraryDependencies ++= Seq(
      "com.47deg" %% "github4s" % "0.33.3",
      "org.scalameta" %% "munit" % "1.1.1" % Test
    )
  )
