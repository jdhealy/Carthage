import subprocess
import sys

# Only run on CI for integration tests.

proc = subprocess.Popen(['carthage', 'bootstrap', '--use-submodules', '--no-build', '--no-use-binaries'], stderr=subprocess.PIPE)
for line in iter(proc.stderr.readline, ''):
	if 'Illegal instruction' in line:
		print 'killing'
		proc.kill()
		sys.exit(1)
