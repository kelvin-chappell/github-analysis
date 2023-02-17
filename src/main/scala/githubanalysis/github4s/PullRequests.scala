package githubanalysis.github4s

import cats.Functor
import cats.effect.unsafe.implicits.global
import cats.effect.{Concurrent, IO, Temporal}
import cats.syntax.all.toFunctorOps
import github4s.domain.{PRFilterClosed, PRFilterOpen, Pagination, PullRequest}
import github4s.{GHError, GHResponse, Github}
import org.http4s.client.{Client, JavaNetClientBuilder}

import java.time.temporal.ChronoUnit.SECONDS
import java.time.temporal.{ChronoUnit, TemporalUnit}
import java.time.{LocalDate, ZonedDateTime}
import java.util.concurrent.TimeUnit
import scala.concurrent.duration.{Duration, FiniteDuration}
import scala.io
import scala.util.chaining.*

object PullRequests:

  private val owner = "guardian"

  private def isClosedSince(threshold: LocalDate)(pr: PullRequest) =
    pr.closed_at.exists(closed => ZonedDateTime.parse(closed).toLocalDate.isAfter(threshold))

  def closedSince[F[_]: Functor](
      github: Github[F],
      repoName: String,
      threshold: LocalDate
  ): F[Either[GHError, List[PullRequest]]] =
    github.pullRequests
      .listPullRequests(owner, repoName, List(PRFilterClosed), Some(Pagination(1, 100)))
      .map(_.result.map(_.filter(isClosedSince(threshold))))

  def openDuration(pr: PullRequest): Option[FiniteDuration] =
    pr.closed_at
      .map(ZonedDateTime.parse)
      .map(closed =>
        Duration(
          closed.toEpochSecond - ZonedDateTime.parse(pr.created_at).toEpochSecond,
          TimeUnit.SECONDS
        )
      )
