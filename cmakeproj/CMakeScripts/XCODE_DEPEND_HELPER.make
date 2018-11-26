# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.htree.Debug:
/Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/Debug/libhtree.a:
	/bin/rm -f /Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/Debug/libhtree.a


PostBuild.htree.Release:
/Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/Release/libhtree.a:
	/bin/rm -f /Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/Release/libhtree.a


PostBuild.htree.MinSizeRel:
/Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/MinSizeRel/libhtree.a:
	/bin/rm -f /Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/MinSizeRel/libhtree.a


PostBuild.htree.RelWithDebInfo:
/Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/RelWithDebInfo/libhtree.a:
	/bin/rm -f /Users/scisci/xcode/Rotophone/cmakeproj/extern/htreecpp/htree/RelWithDebInfo/libhtree.a




# For each target create a dummy ruleso the target does not have to exist
