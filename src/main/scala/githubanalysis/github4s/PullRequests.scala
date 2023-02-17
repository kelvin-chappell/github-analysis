package githubanalysis.github4s

import cats.effect.unsafe.implicits.global
import cats.effect.{Concurrent, IO, Temporal}
import cats.syntax.all.toFunctorOps
import cats.{Functor, Monad}
import github4s.domain.{PRFilterClosed, PRFilterOpen, Pagination, PullRequest}
import github4s.{GHError, GHResponse, Github}
import githubanalysis.fp.Reader
import org.http4s.client.{Client, JavaNetClientBuilder}

import java.time.temporal.{ChronoUnit, TemporalUnit}
import java.time.{LocalDate, ZonedDateTime}
import java.util.concurrent.TimeUnit.SECONDS
import scala.concurrent.duration.{Duration, FiniteDuration}
import scala.io

object PullRequests:

  private val owner = "guardian"

  private def isClosedSince(threshold: LocalDate)(pr: PullRequest) =
    pr.closed_at.exists(closed => ZonedDateTime.parse(closed).toLocalDate.isAfter(threshold))

  def closedSince[M[_]: Monad](
      threshold: LocalDate,
      repoName: String
  ): Reader[Github[M], M[Either[GHError, List[PullRequest]]]] =
    Reader(
      _.pullRequests
        .listPullRequests(owner, repoName, List(PRFilterClosed), Some(Pagination(1, 100)))
        .map(_.result.map(_.filter(isClosedSince(threshold))))
    )

  def openDuration(pr: PullRequest, now: ZonedDateTime): FiniteDuration =
    val endTime = pr.closed_at.map(ZonedDateTime.parse).getOrElse(now)
    Duration(endTime.toEpochSecond - ZonedDateTime.parse(pr.created_at).toEpochSecond, SECONDS)
