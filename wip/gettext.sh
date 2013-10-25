source /local32/etc/profile.local

# set CPU count global. This can be overwrite from the compiler script (ffmpeg-autobuild.bat)
cpuCount=6
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

#make mingw libs static
if [ -d "mingw32/lib/libgfortran.dll.a" ]; then mv mingw32/lib/libgfortran.dll.a.old; fi
if [ -d "mingw32/lib/libgomp.dll.a" ]; then mv mingw32/lib/libgomp.dll.a.old; fi
if [ -d "mingw32/lib/libquadmath.dll.a" ]; then mv mingw32/lib/libquadmath.dll.a.old; fi
if [ -d "mingw32/lib/libssp.dll.a" ]; then mv mingw32/lib/libssp.dll.a.old; fi

cd $LOCALBUILDDIR
if [ -f "libiconv-1.14/compile.done" ]; then
    echo -------------------------------------------------
    echo "libiconv-1.14 is already compiled"
    echo -------------------------------------------------
    else 
		wget -c http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
		tar xzf libiconv-1.14.tar.gz
		rm libiconv-1.14.tar.gz
		cd libiconv-1.14
		./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
		make -j $cpuCount
		make install
		echo "finish" > compile.done
		
		if [ -f "$LOCALDESTDIR/lib/libiconv.a" ]; then
			echo -
			echo -------------------------------------------------
			echo "build libiconv-1.14 done..."
			echo -------------------------------------------------
			echo -
			else
				echo -------------------------------------------------
				echo "build libiconv-1.14 failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi
fi

cd $LOCALBUILDDIR
wget -c http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.3.1.tar.gz
tar xzf gettext-0.18.3.1.tar.gz
mv gettext-0.18.3.1 gettext-0.18.3.1-runtime
cd gettext-0.18.3.1-runtime
cat gettext-tools/woe32dll/gettextlib-exports.c | grep -v rpl_opt > gettext-tools/woe32dll/gettextlib-exports.c.new
mv gettext-tools/woe32dll/gettextlib-exports.c.new gettext-tools/woe32dll/gettextlib-exports.c
CFLAGS="-mms-bitfields -mthreads -O2" ./configure --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -DPTW32_STATIC_LIB" 
cd gettext-runtime
make -j $cpuCount
make install

cd $LOCALBUILDDIR
tar xzf gettext-0.18.3.1.tar.gz
rm gettext-0.18.3.1.tar.gz
mv gettext-0.18.3.1 gettext-0.18.3.1-static
cd gettext-0.18.3.1-static
CFLAGS="-mms-bitfields -mthreads -O2" ./configure --prefix=$LOCALDESTDIR --enable-threads=win32 --enable-relocatable --disable-shared LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
make -j $cpuCount
install gettext-tools/src/*.exe $LOCALDESTDIR/bin
install gettext-tools/misc/autopoint $LOCALDESTDIR/bin

cd $LOCALBUILDDIR
cd libiconv-1.14
./configure --prefix=$LOCALDESTDIR --enable-shared=no --enable-static=yes LDFLAGS="-L$LOCALDESTDIR/lib -mthreads -static -static-libgcc -static-libstdc++ -DPTW32_STATIC_LIB" 
make clean
make -j $cpuCount
make install