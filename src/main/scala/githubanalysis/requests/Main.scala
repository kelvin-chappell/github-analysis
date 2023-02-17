package githubanalysis.requests

import githubanalysis.Env

import java.time.{LocalDate, ZonedDateTime}
import io.circe.{Decoder, Encoder, parser}
import io.circe._, io.circe.generic.auto._, io.circe.parser._, io.circe.syntax._

@main
def main(): Unit =
  val owner = "guardian"
  val repo = "identity"
  val num = 3
  val accessToken = Env()("GITHUB_TOKEN")
  val r = requests.get(
    s"https://api.github.com/repos/$owner/$repo/pulls",
    params = Map("state" -> "closed", "per_page" -> num.toString),
    headers = Map(
      "Accept" -> "application/vnd.github+json",
      "Authorization" -> s"Bearer $accessToken",
      "X-GitHub-Api-Version" -> "2022-11-28"
    )
  )
  println(r.statusCode)
  println(r.text())
  val jsonObject = parser.parse(r.text()).right.get
  println(jsonObject)
