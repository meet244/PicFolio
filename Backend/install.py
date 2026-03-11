import subprocess
import sys
import shutil
import os

def run_pip(args):
    try:
        subprocess.check_call([sys.executable, "-m", "pip"] + args)
    except subprocess.CalledProcessError as e:
        print(f"Error running pip: {e}")
        sys.exit(1)

def main():
    # Check if running in a virtual environment
    in_venv = sys.prefix != sys.base_prefix
    if not in_venv:
        print("Warning: You are not running inside a virtual environment.")
        print("It is recommended to run this script inside a virtual environment (e.g., 'venv').\nDo you want to create a virtual environment? (y/n): ")
        if input().lower() == 'y':
            # make venv of py 3.11.9
            subprocess.check_call(["py", "-3.11", "-m", "venv", "venv"])
            
            print("Virtual environment created successfully.")
            print("Now you can run the program with 'source venv/Scripts/activate'")
            print("Then run 'python install.py'")
            print("\n")
            sys.exit(0)

    print("1. Installing requirements from requirements.txt...")
    req_path = os.path.join(os.path.dirname(__file__), 'requirements.txt')
    if os.path.exists(req_path):
        run_pip(["install", "-r", req_path])
    else:
        print(f"Error: {req_path} not found.")
        sys.exit(1)

    print("\n2. Checking for CUDA availability...")
    has_cuda = False
    if shutil.which('nvidia-smi') is not None:
        try:
            subprocess.check_call(['nvidia-smi'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print("NVIDIA GPU detected via nvidia-smi.")
            has_cuda = True
        except subprocess.CalledProcessError:
            print("nvidia-smi found but returned error. Assuming no CUDA.")
    else:
        print("nvidia-smi not found. Assuming no CUDA.")

    print("\n3. Installing PyTorch...")
    if has_cuda:
        print("Installing PyTorch with CUDA 12.1 support...")
        # pip install torch==2.5.1+cu121 --extra-index-url https://download.pytorch.org/whl/cu121
        # pip install torchvision==0.20.1+cu121 --extra-index-url https://download.pytorch.org/whl/cu121
        run_pip([
            "install", 
            "torch==2.5.1+cu121", 
            "torchvision==0.20.1+cu121", 
            "--extra-index-url", "https://download.pytorch.org/whl/cu121"
        ])
    else:
        print("Installing PyTorch (CPU version)...")
        # install torch==2.5.1 cpu version and torchvision==0.20.1 cpu version
        run_pip(["install", "torch==2.5.1", "torchvision==0.20.1"])

    print("\nInstallation complete!")
    print("Now you can run the program with 'python backend/start.py'")
    print()

if __name__ == "__main__":
    main()
