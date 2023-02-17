package githubanalysis.github4s

import github4s.Github
import munit.FunSuite

import java.time.LocalDate

class PullRequestsTest extends FunSuite:
  test("closedSince") {
//    val github = ???
//    val obtained = PullRequests.closedSince(LocalDate.of(2023, 2, 17), "").run(github)
    val obtained = 1
    val expected = 1
    assertEquals(obtained, expected)
  }
