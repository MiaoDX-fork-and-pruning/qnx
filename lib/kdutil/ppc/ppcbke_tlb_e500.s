#
# $QNXLicenseA:
# Copyright 2007, QNX Software Systems. All Rights Reserved.
# 
# You must obtain a written license from and pay applicable license fees to QNX 
# Software Systems before you may reproduce, modify or distribute this software, 
# or any work that includes all or part of this software.   Free development 
# licenses are available for evaluation and non-commercial purposes.  For more 
# information visit http://licensing.qnx.com or email licensing@qnx.com.
#  
# This file may contain contributions from others.  Please review this entire 
# file for other proprietary rights or license notices, as well as the QNX 
# Development Suite License Guide at http://licensing.qnx.com/license-guide/ 
# for other information.
# $
#


	.include "ppc/util.ah"
	.include "asmoff.def"


.ifdef PPC_CPUOP_ENABLED
	.cpu booke32
.endif

#
# Motorola E500 versions of book E TLB routines. Standards, gotta love 'em :-(
#

routine_start ppcbke_tlb_write_e500, 1
	# R3 - tlb
	# R4 - idx
	# R5 - struct ppcbke_tlb *

	#NYI: make sure interrupts are disabled.

	lwz		%r9,PPCBKE_TLB_EPN(%r5)

	rlwinm	%r6,%r3,63-35,34-32,35-32	# TSEL

	# With TLB0, we only want to stick the low order bit
	# in the MAS0.ESEL field. The others go in the MAS2.EPN bits 45-51
	# NYI: Can make the decision based on the TLBnCFG.ASSOC field value.
	cmplwi	%r3,0
	bne		1f
	rlwimi	%r9,%r4,62-51,45-32,51-32
	andi.	%r4,%r4,1
1:
	rlwimi	%r6,%r4,63-47,36-32,47-32	# ESEL
	mtspr	PPCBKEM_SPR_MAS0,%r6

	lbz		%r6,PPCBKE_TLB_V(%r5)
	rlwinm	%r6,%r6,31,0,0
	lbz		%r7,PPCBKE_TLB_SIZE(%r5)
	rlwimi	%r6,%r7,63-55,52-32,55-32
	lbz		%r7,PPCBKE_TLB_TS(%r5)
	rlwimi	%r6,%r7,63-51,51-32,51-32
	lwz		%r7,PPCBKE_TLB_TID(%r5)
	rlwimi	%r6,%r7,63-47,36-32,47-32
	lhz		%r8,PPCBKE_TLB_ATTR(%r5)
	rlwimi	%r6,%r8,48-33,33-32,33-32	# IPROT bit
	mtspr	PPCBKEM_SPR_MAS1,%r6

	rlwimi	%r9,%r8,0,59-32,63-32		# WIMGE bits	
	rlwimi	%r9,%r8,32-8,57-32,58-32	# X0,X1 bits
	rlwimi	%r9,%r8,32-3,54-32,54-32	# SHAREN bit
	mtspr	PPCBKEM_SPR_MAS2,%r9

.ifdef __LITTLEENDIAN__
	lwz		%r6,PPCBKE_TLB_RPN+0(%r5)
.else
	lwz		%r6,PPCBKE_TLB_RPN+4(%r5)
.endif
	rlwimi	%r6,%r8,32-2,54-32,57-32	# U0-U3 bits
	lbz		%r7,PPCBKE_TLB_ACCESS(%r5)
	rlwimi	%r6,%r7,0,63-32,63-32		# SR
	rlwimi	%r6,%r7,1,61-32,61-32		# SW
	rlwimi	%r6,%r7,2,59-32,59-32		# SX
	rlwimi	%r6,%r7,30,62-32,62-32		# UR
	rlwimi	%r6,%r7,31,60-32,60-32		# UW
	rlwimi	%r6,%r7,0,58-32,58-32		# UX
	mtspr	PPCBKEM_SPR_MAS3,%r6
	
	tlbwe	%r0,%r0,%r0
	
	isync

	#NYI: make sure interrupts are restored
	blr
routine_end ppcbke_tlb_write_e500

routine_start ppcbke_tlb_read_e500, 1
	# R3 - tlb
	# R4 - idx
	# R5 - struct ppcbke_tlb *

	#NYI: make sure interrupts are disabled.

	mr		%r9,%r4

	rlwinm	%r6,%r3,63-35,34-32,35-32	# TSEL

	# With TLB0, we only want to stick the low order bit
	# in the MAS0.ESEL field. The others go in the MAS2.EPN bits 45-51
	# NYI: Could make the decision based on the TLBnCFG.ASSOC field value.
	cmplwi	%r3,0
	bne		1f
	rlwinm	%r6,%r4,62-51,45-32,51-32
	andi.	%r9,%r4,1
	mtspr	PPCBKEM_SPR_MAS2,%r6
1:
	rlwimi	%r6,%r9,63-47,36-32,47-32	# ESEL
	mtspr	PPCBKEM_SPR_MAS0,%r6

	tlbre	%r0,%r0,%r0		# operands ignored

	mfspr	%r6,PPCBKEM_SPR_MAS1
	mfspr	%r7,PPCBKEM_SPR_MAS2
	mfspr	%r8,PPCBKEM_SPR_MAS3

	#NYI: make sure interrupts are restored

	cmplwi	%r3,0
	bne		1f
	# Make sure the EPN address bits that control which entry the
	# thing goes into match up with the requested index
	rlwimi	%r7,%r4,11,45-32,51-32
1:

	rlwinm	%r9,%r6,1,31,31
	stb		%r9,PPCBKE_TLB_V(%r5)
	rlwinm	%r9,%r6,47-31,31-12,31
	stw		%r9,PPCBKE_TLB_TID(%r5)
	rlwinm	%r9,%r6,51-31,31,31
	stb		%r9,PPCBKE_TLB_TS(%r5)
	rlwinm	%r9,%r6,55-31,28,31
	stb		%r9,PPCBKE_TLB_SIZE(%r5)
	rlwinm	%r9,%r8,0,32-32,51-32
	li		%r10,0
.ifdef __LITTLEENDIAN__
	stw		%r9,PPCBKE_TLB_RPN+0(%r5)
	stw		%r10,PPCBKE_TLB_RPN+4(%r5)
.else
	stw		%r9,PPCBKE_TLB_RPN+4(%r5)
	stw		%r10,PPCBKE_TLB_RPN+0(%r5)
.endif
	rlwinm	%r9,%r7,0,32-32,51-32
	stw		%r9,PPCBKE_TLB_EPN(%r5)
	rlwinm	%r9,%r7,0,27,31			# WIMGE bits
	rlwimi	%r9,%r8,2,20,23			# U0-U3 bits
	rlwimi	%r9,%r7,3,19,19			# SHAREN bit
	rlwimi	%r9,%r7,8,17,18			# X0,X1 bits
	rlwimi	%r9,%r6,17,16,16		# IPROT bit
	sth		%r9,PPCBKE_TLB_ATTR(%r5)

	rlwinm	%r9,%r8,0,31,31			# SR bit
	rlwimi	%r9,%r8,31,30,30		# SW bit
	rlwimi	%r9,%r8,30,29,29		# SX bit
	rlwimi	%r9,%r8,2,28,28			# UR bit
	rlwimi	%r9,%r8,1,27,27			# UW bit
	rlwimi	%r9,%r8,0,26,26			# UX bit
	stb		%r9,PPCBKE_TLB_ACCESS(%r5)

	blr
routine_end ppcbke_tlb_read_e500
