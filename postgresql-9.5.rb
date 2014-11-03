require 'formula'

class Postgresql95 < Formula
  homepage 'http://www.postgresql.org/'

  head do
    url 'http://git.postgresql.org/git/postgresql.git', :branch => 'master'

    depends_on 'petere/sgml/docbook-dsssl' => :build
    depends_on 'petere/sgml/docbook-sgml' => :build
    depends_on 'petere/sgml/openjade' => :build
    patch :DATA
  end

  keg_only 'The different provided versions of PostgreSQL conflict with each other.'

  env :std

  depends_on 'e2fsprogs'
  depends_on 'gettext'
  depends_on 'openssl'
  depends_on 'readline'

  def install
    args = ["--prefix=#{prefix}",
            "--enable-dtrace",
            "--enable-nls",
            "--with-bonjour",
            "--with-gssapi",
            "--with-ldap",
            "--with-libxml",
            "--with-libxslt",
            "--with-openssl",
            "--with-uuid=e2fs",
            "--with-pam",
            "--with-perl",
            "--with-python",
            "--with-tcl"]

    args << "--with-extra-version=+git" if build.head?

    system "./configure", *args
    system "make install-world"
  end

  def caveats; <<-EOS.undent
    To use this PostgreSQL installation, do one or more of the following:

    - Call all programs explicitly with #{opt_prefix}/bin/...
    - Add #{opt_prefix}/bin to your PATH
    - brew link -f #{name}
    - Install the postgresql-common package
    EOS
  end

  test do
    system "#{bin}/initdb", "pgdata"
  end
end


__END__
diff --git a/src/interfaces/libpq/fe-connect.c b/src/interfaces/libpq/fe-connect.c
index 3fe8c21..7832324 100644
--- a/src/interfaces/libpq/fe-connect.c
+++ b/src/interfaces/libpq/fe-connect.c
@@ -373,7 +373,7 @@ static int parseServiceFile(const char *serviceFile,
         PQconninfoOption *options,
         PQExpBuffer errorMessage,
         bool *group_found);
-static char *pwdfMatchesString(char *buf, char *token);
+static char *pwdfMatchesString(char *buf, char *token, bool is_hostname);
 static char *PasswordFromFile(char *hostname, char *port, char *dbname,
         char *username);
 static bool getPgPassFilename(char *pgpassfile);
@@ -5542,7 +5542,7 @@ defaultNoticeProcessor(void *arg, const char *message)
  * token doesn't match
  */
 static char *
-pwdfMatchesString(char *buf, char *token)
+pwdfMatchesString(char *buf, char *token, bool is_hostname)
 {
  char     *tbuf,
         *ttok;
@@ -5556,6 +5556,18 @@ pwdfMatchesString(char *buf, char *token)
    return tbuf + 2;
  while (*tbuf != 0)
  {
+   /* '*' matches everything until '.' or end, but only for the hostname */
+   if (*tbuf == '*' && (*(tbuf + 1) == '.' || *(tbuf + 1) == ':') &&
+     !bslash && is_hostname)
+   {
+     tbuf++;
+     while (*ttok != *tbuf)
+     {
+       if (*ttok == 0)
+         return (*tbuf == ':') ? tbuf + 1 : NULL;
+       ttok++;
+     }
+   }
    if (*tbuf == '\\' && !bslash)
    {
      tbuf++;
@@ -5664,10 +5676,10 @@ PasswordFromFile(char *hostname, char *port, char *dbname, char *username)
    if (buf[len - 1] == '\n')
      buf[len - 1] = 0;
 
-   if ((t = pwdfMatchesString(t, hostname)) == NULL ||
-     (t = pwdfMatchesString(t, port)) == NULL ||
-     (t = pwdfMatchesString(t, dbname)) == NULL ||
-     (t = pwdfMatchesString(t, username)) == NULL)
+   if ((t = pwdfMatchesString(t, hostname, true)) == NULL ||
+     (t = pwdfMatchesString(t, port, false)) == NULL ||
+     (t = pwdfMatchesString(t, dbname, false)) == NULL ||
+     (t = pwdfMatchesString(t, username, false)) == NULL)
      continue;
    ret = strdup(t);
    fclose(fp);
