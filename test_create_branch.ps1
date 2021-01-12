$version = 2.5.4

$splitVers = GetVersionFromParam @version

git checkout -b $splitVers.Minor+1