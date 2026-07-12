Version 0.1

atomsInstall('sciTorch');

Getting the thirdparty payloads
--------------------------------
Native runtime payloads (libtorch, OpenCV) are not tracked in git. Fresh
clones must run: ./fetch-thirdparty.sh (downloads + verifies + installs
both into thirdparty/, see that script's header for details/flags).
