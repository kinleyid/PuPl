
import dastr, os

# Get project directory
proj_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
data_path = os.path.join(proj_path, 'data-raw')
print(data_path)

# Read attributes: subject number and acquisition number
files = dastr.read(
	path=data_path,
	params=[
		("cS(\d+)_b(\d+)\.edf", "sub", "acq")
		],
	disp=True)

# zfill subject numbers (1 -> 01, etc.)
for i in range(len(files)):
	files[i]["attrs"]["sub"] = files[i]["attrs"]["sub"].zfill(2)

# Write to /raw/
new_path = os.path.join(proj_path, 'raw')
destinations = dastr.write(
	files=files,
	path=new_path,
	params=[
		("sub-%s", "sub"),
		"eyetrack",
		("sub-%s_task-listen_acq-%s_eyetrack.edf", "sub", "acq")
		],
	key='c',
	disp=True)
