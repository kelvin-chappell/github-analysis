package githubanalysis.github4s

import cats.effect.IO
import cats.effect.unsafe.implicits.global
import github4s.Github
import org.http4s.client.{Client, JavaNetClientBuilder}

import java.time.LocalDate
import scala.io

@main
def main(): Unit =
  PullRequests
    .closedSince(
      github = Github[IO](
        client = JavaNetClientBuilder[IO].create,
        accessToken = Env().get("GITHUB_TOKEN")
      ),
      repoName = "identity",
      threshold = LocalDate.now().minusWeeks(1)
    )
    .flatMap {
      case Left(e) => IO.println(s"Something went wrong: ${e.getMessage}")
      case Right(prs) =>
        IO.pure(
          prs.foreach(pr =>
            println(s"${pr.html_url}: ${pr.title}: ${PullRequests.openDuration(pr).map(_.toDays)}")
          )
        )
    }
    .unsafeRunSync()
