module profiler();

`define VPU_PATH          TestDriver.testHarness.chiptop0.system.tile_prci_domain.element_reset_domain_shuttle_tile.vector_unit
`define VPU_FRONTEND_PATH `VPU_PATH.vfu
`define VPU_DISPATCH_PATH `VPU_PATH.dis
`define VPU_BACKEND_PATH  `VPU_PATH.vu

// description events
// vF - VPU Frontend, Fault Check
// vD - VPU Dispatcher, in the same clk, instr is forward to vector decoding
// vISQ - instruction have been added to issue queue
// vE   - instruction sent from ISQ to exec unit
// vLSU - instruction sent from ISQ to load/store seq
// TODO:
// vRt  - ????  
// vWB 

  string pc_to_mnemonic [longint];
  string pc_to_opcode [longint];
  integer logfile;
  initial begin
  // $system("echo 'initial at ['$(date)']'>>temp.log");
  logfile = $fopen("kanata.log","w"); // or open with "w" to start fresh
  $fwrite(logfile, "Kanata\t0004\n");
  // another way to write $fdisplay(logfile, "Kanta\t0004\n");
  get_pc_to_mnemonic_map();
//   $fwrite(logfile, "mnemonic size: %d\n", pc_to_mnemonic.size());
  end

  longint post_release_queue [$];  
  int post_release_scheduled = 0;

  logic   hndshk_instr_init;
  logic   hndshk_instr_dispatch;
  logic   hndshk_instr_issue_vlissq;
  logic   hndshk_instr_issue_vsissq;
  logic   hndshk_instr_issue_vxissq_int;
  logic   hndshk_instr_issue_vpissq;
  logic   hndshk_instr_issue_vxissq_fp;
  logic   hndshk_instr_exec_vlissq;
  logic   hndshk_instr_exec_vsissq;
  logic   hndshk_instr_exec_vpissq;
  logic   hndshk_instr_exec_vxissq_int;
  logic   hndshk_instr_exec_vxissq_fp;

  
  longint cnt_in_vfu_ff  = 0;
  longint cnt_out_vfu_ff = 0;
  
  longint cnt_in_vfu_next  = 0;
  longint cnt_out_vfu_next = 0;
  longint instr_id_by_vat [longint];


  // handshakes
//   assign hndshk_instr_init          = `VPU_FRONTEND_PATH.io_core_ex_ready   &  `VPU_FRONTEND_PATH.io_core_ex_valid &`VPU_FRONTEND_PATH.io_core_ex_fire ;
  assign hndshk_instr_dispatch      = `VPU_DISPATCH_PATH.io_dis_ready   &  `VPU_DISPATCH_PATH.io_dis_valid;
  assign hndshk_instr_init = hndshk_instr_dispatch;
  //load/store
  assign hndshk_instr_issue_vlissq      =  `VPU_BACKEND_PATH.vlissq.io_enq_ready &  `VPU_BACKEND_PATH.vlissq.io_enq_valid;
  assign hndshk_instr_issue_vsissq      =  `VPU_BACKEND_PATH.vsissq.io_enq_ready &  `VPU_BACKEND_PATH.vsissq.io_enq_valid;
  assign hndshk_instr_issue_vpissq      =  `VPU_BACKEND_PATH.vpissq.io_enq_ready &  `VPU_BACKEND_PATH.vpissq.io_enq_valid;
  assign hndshk_instr_issue_vxissq_int  =  `VPU_BACKEND_PATH.vxissq_int.io_enq_ready &  `VPU_BACKEND_PATH.vxissq_int.io_enq_valid;
  assign hndshk_instr_issue_vxissq_fp   =  `VPU_BACKEND_PATH.vxissq_fp.io_enq_ready &  `VPU_BACKEND_PATH.vxissq_fp.io_enq_valid;
  assign hndshk_instr_exec_vlissq       =  `VPU_BACKEND_PATH.vlissq.io_deq_ready &  `VPU_BACKEND_PATH.vlissq.io_deq_valid;
  assign hndshk_instr_exec_vsissq       =  `VPU_BACKEND_PATH.vsissq.io_deq_ready &  `VPU_BACKEND_PATH.vsissq.io_deq_valid;
  assign hndshk_instr_exec_vpissq       =  `VPU_BACKEND_PATH.vpissq.io_deq_ready &  `VPU_BACKEND_PATH.vpissq.io_deq_valid;
  assign hndshk_instr_exec_vxissq_int   =  `VPU_BACKEND_PATH.vxissq_int.io_deq_ready &  `VPU_BACKEND_PATH.vxissq_int.io_deq_valid;
  assign hndshk_instr_exec_vxissq_fp    =  `VPU_BACKEND_PATH.vxissq_fp.io_deq_ready &  `VPU_BACKEND_PATH.vxissq_fp.io_deq_valid;
  // counters input/output frontend
  assign cnt_in_vfu_next  = cnt_in_vfu_ff  + hndshk_instr_init;
  assign cnt_out_vfu_next = cnt_out_vfu_ff + hndshk_instr_dispatch; 
  
  always_ff @(posedge `VPU_PATH.clock) begin
     cnt_in_vfu_ff   <= cnt_in_vfu_next;
     cnt_out_vfu_ff  <= cnt_out_vfu_next;
      // create new instr ID
     if (hndshk_instr_dispatch) begin
        instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_tail] = cnt_out_vfu_next;   
     end
  end

  always @(posedge `VPU_PATH.clock) begin
    if (!`VPU_PATH.reset) begin
    if (hndshk_instr_init) begin
      $fwrite(logfile, "I\t%0d\t0\t0\n",   cnt_in_vfu_next);
    //   $fwrite(logfile, "L\t%0d\t0\t%x\n",  cnt_in_vfu_next, `VPU_DISPATCH_PATH.io_issue_bits_bits);
    //   $fwrite(logfile, "L\t%0d\t0\t%x\n",  cnt_in_vfu_next, `VPU_FRONTEND_PATH.io_core_ex_uop_pc);

      $fwrite(logfile, "L\t%0d\t0\t%s\n",  cnt_in_vfu_next, pc_to_mnemonic[`VPU_FRONTEND_PATH.io_core_com_pc]);

      $fwrite(logfile, "S\t%0d\t0\tF\n",   cnt_in_vfu_next);
    end

    if (hndshk_instr_dispatch) begin
        // $fwrite(logfile, "L\t%0d\t0\t%x\n",  cnt_out_vfu_next, `VPU_DISPATCH_PATH.io_vat_tail);
        $fwrite(logfile, "S\t%0d\t0\tvD\n", cnt_out_vfu_next);
    end

    // Issue Queue
    if (hndshk_instr_issue_vlissq) begin
      $fwrite(logfile, "S\t%0d\t0\tvISQ\n", instr_id_by_vat[`VPU_BACKEND_PATH.vlissq.io_enq_bits_vat]);
    end
    if (hndshk_instr_issue_vsissq) begin
      $fwrite(logfile, "S\t%0d\t0\tvISQ\n", instr_id_by_vat[`VPU_BACKEND_PATH.vsissq.io_enq_bits_vat]);
    end
    if (hndshk_instr_issue_vpissq) begin
      $fwrite(logfile, "S\t%0d\t0\tvISQ\n", instr_id_by_vat[`VPU_BACKEND_PATH.vpissq.io_enq_bits_vat]);
    end
    if (hndshk_instr_issue_vxissq_int) begin
      $fwrite(logfile, "S\t%0d\t0\tvISQ\n", instr_id_by_vat[`VPU_BACKEND_PATH.vxissq_int.io_enq_bits_vat]);
    end
    if (hndshk_instr_issue_vxissq_fp) begin
      $fwrite(logfile, "S\t%0d\t0\tvISQ\n", instr_id_by_vat[`VPU_BACKEND_PATH.vxissq_fp.io_enq_bits_vat]);
    end

    // vLSU
    if (hndshk_instr_exec_vlissq) begin
      $fwrite(logfile, "S\t%0d\t0\tvLSU\n", instr_id_by_vat[`VPU_BACKEND_PATH.vlissq.io_deq_bits_vat]);
    end
    if (hndshk_instr_exec_vsissq) begin
      $fwrite(logfile, "S\t%0d\t0\tvLSU\n", instr_id_by_vat[`VPU_BACKEND_PATH.vsissq.io_deq_bits_vat]);
    end
    if (hndshk_instr_exec_vpissq) begin
      $fwrite(logfile, "S\t%0d\t0\tvE\n", instr_id_by_vat[`VPU_BACKEND_PATH.vpissq.io_deq_bits_vat]);
    end
    if (hndshk_instr_exec_vxissq_int) begin
      $fwrite(logfile, "S\t%0d\t0\tvE\n", instr_id_by_vat[`VPU_BACKEND_PATH.vxissq_int.io_deq_bits_vat]);
    end
    if (hndshk_instr_exec_vxissq_fp) begin
      $fwrite(logfile, "S\t%0d\t0\tvE\n", instr_id_by_vat[`VPU_BACKEND_PATH.vxissq_fp.io_deq_bits_vat]);
    end

    // Retire

    if (post_release_scheduled) begin
        post_release_scheduled=0;
        foreach(post_release_queue[id])
          $fwrite(logfile, "R\t%0d\t0\t0\n", post_release_queue[id]);
        post_release_queue = {};
    end


    if (`VPU_DISPATCH_PATH.io_vat_release_0_valid) begin
      $fwrite(logfile, "S\t%0d\t0\tvRt\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_0_bits]);
    //   $fwrite(logfile, "R\t%0d\t0\t0\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_0_bits]);
      post_release_scheduled = 1;
      post_release_queue.push_back(instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_0_bits]);
    //   post_release_id = `VPU_DISPATCH_PATH.io_vat_release_0_bits;
      instr_id_by_vat.delete(`VPU_DISPATCH_PATH.io_vat_release_0_bits);
    end
    if (`VPU_DISPATCH_PATH.io_vat_release_1_valid) begin
      $fwrite(logfile, "S\t%0d\t0\tvRt\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_1_bits]);
    //   assert(!post_release_scheduled);
    //   $fwrite(logfile, "R\t%0d\t0\t0\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_1_bits]);
      post_release_scheduled = 1;
    //   post_release_id = `VPU_DISPATCH_PATH.io_vat_release_1_bits;
      post_release_queue.push_back(instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_1_bits]);

      instr_id_by_vat.delete(`VPU_DISPATCH_PATH.io_vat_release_1_bits);
    end
    if (`VPU_DISPATCH_PATH.io_vat_release_2_valid) begin
      $fwrite(logfile, "S\t%0d\t0\tvRt\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_2_bits]);
    //   assert(!post_release_scheduled);
    //   $fwrite(logfile, "R\t%0d\t0\t0\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_2_bits]);
      post_release_scheduled = 1;
    //   post_release_id = `VPU_DISPATCH_PATH.io_vat_release_2_bits;
      post_release_queue.push_back(instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_2_bits]);

      instr_id_by_vat.delete(`VPU_DISPATCH_PATH.io_vat_release_2_bits);
    end
    if (`VPU_DISPATCH_PATH.io_vat_release_3_valid) begin
      $fwrite(logfile, "S\t%0d\t0\tvRt\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_3_bits]);
    //   assert(!post_release_scheduled);
    //   $fwrite(logfile, "R\t%0d\t0\t0\n", instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_3_bits]);
      post_release_scheduled = 1;
    //   post_release_id = `VPU_DISPATCH_PATH.io_vat_release_3_bits;
      post_release_queue.push_back(instr_id_by_vat[`VPU_DISPATCH_PATH.io_vat_release_3_bits]);

      instr_id_by_vat.delete(`VPU_DISPATCH_PATH.io_vat_release_3_bits);
    end



    $fwrite(logfile, "C\t1\n");
    end
  end
    
    
    final begin
      $fclose(logfile);
    end

    function automatic void get_pc_to_mnemonic_map ();
    string          tmp_dump_name = "tmp_dump_disasm";
    int unsigned    tmp_pc_to_mnemonic_fhandle;
    string          elf_dir;
    string          tmp_str[];
    longint         tmp_pc;
    longint         tmp_opcode;
    string          tmp_line;
    string          tmp_data;

    string elf_file = "./disasm.d";
    tmp_dump_name = elf_file;
    if (elf_file != "") begin
      // Convert elf to dump, remove all except lines containing pc to mnemonic, remove unneded spaces
      // void'($system($sformatf("riscv64-unknown-elf-objdump -d '%s' | grep -v 'Disassembly\\|>:\\|./\\|^$\\|file format\\|\\.\\.\\.'|sed 's/[[:space:]]\\+/ /g' > %s", elf_file, tmp_dump_name)));

      tmp_str = new [5];
      tmp_pc_to_mnemonic_fhandle = $fopen(tmp_dump_name, "r");
      do begin
        void'($fgets(tmp_line, tmp_pc_to_mnemonic_fhandle));
        tmp_str = '{"","","","",""};
        void'($sscanf(tmp_line," %x: %x %s %s %s %s %s", tmp_pc, tmp_opcode, tmp_str[0], tmp_str[1], tmp_str[2], tmp_str[3], tmp_str[4]));
        tmp_data = {tmp_str[0]," ", tmp_str[1], " ", tmp_str[2], " ", tmp_str[3], " ", tmp_str[4]};
        pc_to_mnemonic[tmp_pc] = {tmp_str[0]," ", tmp_str[1], " ", tmp_str[2], " ", tmp_str[3], " ", tmp_str[4]};
        pc_to_opcode[tmp_pc]   = tmp_opcode;
      end while (!$feof(tmp_pc_to_mnemonic_fhandle));
      $fclose(tmp_pc_to_mnemonic_fhandle);
    end else begin
      $display("Path to elf_name not found. No mnemonics in kanata log");
    end
  endfunction : get_pc_to_mnemonic_map
endmodule
