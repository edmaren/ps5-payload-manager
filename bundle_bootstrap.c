/* Standard ps5-elfldr bootstrap + our payload */
#include <signal.h>
#include <stdio.h>
#include <ps5/kernel.h>
#include "elfldr.h"
#include "log.h"
#include "pt.h"

#include "socksrv_elf.c"
#include "pldmgr_elf.c"

static char* const argv_socksrv[] = {"socksrv.elf", 0};
static char* const argv_pldmgr[] = {"pldmgr.elf", 0};

int main() {
  pid_t mypid = getpid();
  uint8_t caps[16];
  uint64_t authid;
  intptr_t vnode;
  int ret_socksrv = 0, ret_pldmgr = 0;

  LOG_PUTS("Spawning bundled payloads...");

  if(elfldr_sanity_check(socksrv_elf, socksrv_elf_len) ||
     elfldr_sanity_check(pldmgr_elf, pldmgr_elf_len)) {
    LOG_PUTS("Corrupted bundled ELF");
    return -1;
  }

  // backup my privileges
  if(!(vnode=kernel_get_proc_rootdir(mypid))) {
    LOG_PUTS("kernel_get_proc_rootdir failed");
    return -1;
  }
  if(kernel_get_ucred_caps(mypid, caps)) {
    LOG_PUTS("kernel_get_ucred_caps failed");
    return -1;
  }
  if(!(authid=kernel_get_ucred_authid(mypid))) {
    LOG_PUTS("kernel_get_ucred_authid failed");
    return -1;
  }

  // launch both in new processes
  if(elfldr_raise_privileges(mypid)) {
    LOG_PUTS("Unable to raise privileges");
    return -1;
  } else {
    signal(SIGCHLD, SIG_IGN);
    
    LOG_PUTS("Spawning socksrv...");
    ret_socksrv = elfldr_spawn(-1, argv_socksrv, socksrv_elf, socksrv_elf_len);
    
    LOG_PUTS("Spawning pldmgr...");
    ret_pldmgr = elfldr_spawn(-1, argv_pldmgr, pldmgr_elf, pldmgr_elf_len);
  }

  // restore my privileges
  kernel_set_proc_jaildir(mypid, vnode);
  kernel_set_proc_rootdir(mypid, vnode);
  kernel_set_ucred_caps(mypid, caps);
  kernel_set_ucred_authid(mypid, authid);

  if (ret_socksrv < 0 || ret_pldmgr < 0) return -1;
  return 0;
}