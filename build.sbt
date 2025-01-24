val awsSdkVersion = "1.11.596"
val scanamoVersion = "1.0.0-M11"

lazy val root = (project in file("."))
  .settings(
    name := "github-analysis",
    scalaVersion := "3.3.4",
    libraryDependencies ++= Seq(
      "com.47deg" %% "github4s" % "0.33.3",
      "org.scalameta" %% "munit" % "1.0.3" % Test,
      "com.amazonaws"               % "aws-java-sdk-s3"            % awsSdkVersion,
      "com.amazonaws"               % "aws-java-sdk-ses"           % awsSdkVersion,
      "com.amazonaws"               % "aws-java-sdk-ssm"           % awsSdkVersion,
      "com.amazonaws"               % "aws-java-sdk-dynamodb"      % awsSdkVersion,
      "com.amazonaws"               % "aws-java-sdk-secretsmanager" % awsSdkVersion,
      "org.quartz-scheduler"        % "quartz"                     % "2.2.3",
      "com.typesafe.scala-logging"  %% "scala-logging"             % "3.9.2",
      "org.scanamo"                 %% "scanamo"                   % scanamoVersion,
      "org.scanamo"                 %% "scanamo-joda"              % scanamoVersion,
      "org.scanamo"                 %% "scanamo-testkit"           % scanamoVersion,
      "com.gu.play-googleauth"      %% "play-v27"                  % "1.0.7",
      "com.gu.play-secret-rotation" %% "aws-parameterstore-sdk-v1" % "0.18",
      "org.scalatest"               %% "scalatest"                 % "3.2.2"    % "test",
      "org.mockito"                 % "mockito-core"               % "1.10.19"  % "test"
    )
  )
