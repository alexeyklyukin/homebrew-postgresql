    patch :DATA


__END__
diff --git a/src/interfaces/libpq/fe-connect.c b/src/interfaces/libpq/fe-connect.c
new file mode 100644
index 18fcb0c..003739f
*** a/src/interfaces/libpq/fe-connect.c
--- b/src/interfaces/libpq/fe-connect.c
*************** static int parseServiceFile(const char *
*** 373,379 ****
           PQconninfoOption *options,
           PQExpBuffer errorMessage,
           bool *group_found);
! static char *pwdfMatchesString(char *buf, char *token);
  static char *PasswordFromFile(char *hostname, char *port, char *dbname,
           char *username);
  static bool getPgPassFilename(char *pgpassfile);
--- 373,379 ----
           PQconninfoOption *options,
           PQExpBuffer errorMessage,
           bool *group_found);
! static char *pwdfMatchesString(char *buf, char *token, bool is_hostname);
  static char *PasswordFromFile(char *hostname, char *port, char *dbname,
           char *username);
  static bool getPgPassFilename(char *pgpassfile);
*************** defaultNoticeProcessor(void *arg, const 
*** 5466,5472 ****
   * token doesn't match
   */
  static char *
! pwdfMatchesString(char *buf, char *token)
  {
    char     *tbuf,
           *ttok;
--- 5466,5472 ----
   * token doesn't match
   */
  static char *
! pwdfMatchesString(char *buf, char *token, bool is_hostname)
  {
    char     *tbuf,
           *ttok;
*************** pwdfMatchesString(char *buf, char *token
*** 5480,5485 ****
--- 5480,5497 ----
      return tbuf + 2;
    while (*tbuf != 0)
    {
+     /* '*' matches everything until '.' or end, but only for the hostname */
+     if (*tbuf == '*' && (*(tbuf + 1) == '.' || *(tbuf + 1) == ':') &&
+       !bslash && is_hostname)
+     {
+       tbuf++;
+       while (*ttok != *tbuf)
+       {
+         if (*ttok == 0)
+           return (*tbuf == ':') ? tbuf + 1 : NULL;
+         ttok++;
+       }
+     }
      if (*tbuf == '\\' && !bslash)
      {
        tbuf++;
*************** PasswordFromFile(char *hostname, char *p
*** 5588,5597 ****
      if (buf[len - 1] == '\n')
        buf[len - 1] = 0;
  
!     if ((t = pwdfMatchesString(t, hostname)) == NULL ||
!       (t = pwdfMatchesString(t, port)) == NULL ||
!       (t = pwdfMatchesString(t, dbname)) == NULL ||
!       (t = pwdfMatchesString(t, username)) == NULL)
        continue;
      ret = strdup(t);
      fclose(fp);
--- 5600,5609 ----
      if (buf[len - 1] == '\n')
        buf[len - 1] = 0;
  
!     if ((t = pwdfMatchesString(t, hostname, true)) == NULL ||
!       (t = pwdfMatchesString(t, port, false)) == NULL ||
!       (t = pwdfMatchesString(t, dbname, false)) == NULL ||
!       (t = pwdfMatchesString(t, username, false)) == NULL)
        continue;
      ret = strdup(t);
      fclose(fp);