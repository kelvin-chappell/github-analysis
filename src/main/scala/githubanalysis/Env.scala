package githubanalysis

import scala.io
import scala.io.BufferedSource

object Env:

  private val env =
    val source = io.Source.fromFile(".env")
    val parsedEnv = source.getLines.map { line =>
      val Array(key, value) = line.split("=")
      key -> value
    }.toMap
    sys.env ++ parsedEnv

  def apply(): Map[String, String] = env
