import sys
import textwrap

import pytest

import check_changelog as cc


def test_check(capsys):
    cc.check(textwrap.dedent("""\
        2019-08-27
          started this test suite

        2019-08-27 15:35
          wrote some tests

        2019-08-27 15:36
          started using copy paste a lot

        2019-08-27 15:35
          wrote some tests
    """).splitlines(True), 'Changelog')

    assert capsys.readouterr().err == (
        'Changelog:10: date out of order (2019-08-27 15:35'
        ' after 2019-08-27 15:36)\n'
        'Changelog:4: 2019-08-27 15:35 previously used here\n'
    )


def test_main_prints_version(monkeypatch, capsys):
    monkeypatch.setattr(sys, 'argv', ['check-changelog', '--version'])
    with pytest.raises(SystemExit):
        cc.main()
    out, err = capsys.readouterr()
    # Python 2 spits --version to stderr, Python 3 fixes that
    assert out + err == (
        '%s\n' % cc.__version__
    )


def test_main(monkeypatch, capsys):
    monkeypatch.setattr(sys, 'argv', ['check-changelog', __file__])
    cc.main()


def test_main_no_such_file(monkeypatch, capsys):
    monkeypatch.setattr(sys, 'argv', ['check-changelog', '/no/such/file'])
    cc.main()
    assert capsys.readouterr().err == (
        "check-changelog: [Errno 2] No such file or directory:"
        " '/no/such/file'\n"
    )


def test_main_no_args(monkeypatch, capsys):
    monkeypatch.setattr(sys, 'argv', ['check-changelog'])
    cc.main()
