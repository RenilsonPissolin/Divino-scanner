// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract DivinoScannerV6 {
    struct Vulnerability { string file; string severity; string bugType; string detail; }
    function scanContract(string memory rawPath, string memory source) public pure returns (Vulnerability[] memory) {
        string memory fileName = extractFileName(rawPath);
        if (contains(source, "interface ") || contains(source, "abstract contract")) return new Vulnerability[](0);
        string memory clean = removeComments(source);
        Vulnerability[] memory tmp = new Vulnerability[](20);
        uint256 c = 0;
        bool hasCall = contains(clean, ".call{") || contains(clean, ".call(");
        if (hasCall) {
            bool guard = contains(clean, "nonReentrant");
            if (!guard) {
                bool cei = isCEIViolation(clean);
                if (cei) tmp[c++] = Vulnerability(fileName, "CRITICAL", "Reentrancy + CEI Violation", "Estado alterado APOS.call - viola CEI");
                else tmp[c++] = Vulnerability(fileName, "CRITICAL", "Reentrancy Risk", "Chamada externa sem nonReentrant");
            }
            if (!contains(clean, "bool success") &&!contains(clean, "require(success")) tmp[c++] = Vulnerability(fileName, "HIGH", "Unchecked Call Return", "Retorno.call nao verificado");
        }
        bool sensitive = contains(clean, "function withdraw") || contains(clean, "function mint") || contains(clean, "function burn") || contains(clean, "function pause") || contains(clean, "function upgrade") || contains(clean, "function setFee");
        if (sensitive) {
            bool prot = contains(clean, "onlyOwner") || contains(clean, "onlyRole") || contains(clean, "onlyAdmin") || contains(clean, "msg.sender ==") || contains(clean, "require(msg.sender");
            if (!prot) tmp[c++] = Vulnerability(fileName, "CRITICAL", "Missing Access Control", "Funcao critica sem controle de acesso");
        }
        if (contains(clean, "unchecked {")) tmp[c++] = Vulnerability(fileName, "MEDIUM", "Unchecked Arithmetic", "Bloco unchecked");
        Vulnerability[] memory res = new Vulnerability[](c);
        for (uint256 i=0;i<c;i++) res[i]=tmp[i];
        return res;
    }
    function isCEIViolation(string memory code) internal pure returns (bool) {
        int256 p = indexOf(code, ".call");
        if (p < 0) return false;
        string memory rest = substring(code, uint256(p), bytes(code).length - uint256(p));
        if (contains(rest, "balances[") || contains(rest, "-=")) return true;
        return false;
    }
    function removeComments(string memory code) internal pure returns (string memory) {
        bytes memory b = bytes(code); bytes memory out = new bytes(b.length); uint256 o=0; bool l=false; bool bl=false;
        for (uint256 i=0;i<b.length;i++) {
            if (!l &&!bl) {
                if (i+1<b.length && b[i]=='/' && b[i+1]=='/') { l=true; i++; continue; }
                if (i+1<b.length && b[i]=='/' && b[i+1]=='*') { bl=true; i++; continue; }
                out[o++]=b[i];
            } else if (l) { if (b[i]=='\n') { l=false; out[o++]=b[i]; } }
            else if (bl) { if (i+1<b.length && b[i]=='*' && b[i+1]=='/') { bl=false; i++; } }
        }
        bytes memory fin = new bytes(o); for (uint256 i=0;i<o;i++) fin[i]=out[i]; return string(fin);
    }
    function extractFileName(string memory path) internal pure returns (string memory) {
        bytes memory b=bytes(path); uint256 last=0; bool f=false; for(uint256 i=0;i<b.length;i++) if(b[i]=='/'){last=i; f=true;}
        if(!f) return path; bytes memory n=new bytes(b.length-last-1); for(uint256 i=last+1;i<b.length;i++) n[i-last-1]=b[i]; return string(n);
    }
    function contains(string memory w, string memory what) internal pure returns (bool) { return indexOf(w, what) >= 0; }
    function indexOf(string memory w, string memory what) internal pure returns (int256) {
        bytes memory a=bytes(w); bytes memory b=bytes(what); if(b.length>a.length) return -1;
        for(uint256 i=0;i<=a.length-b.length;i++){bool ok=true; for(uint256 j=0;j<b.length;j++) if(a[i+j]!=b[j]){ok=false; break;} if(ok) return int256(i);} return -1;
    }
    function substring(string memory s, uint256 st, uint256 len) internal pure returns (string memory) {
        bytes memory b=bytes(s); if(st+len>b.length) len=b.length-st; bytes memory out=new bytes(len); for(uint256 i=0;i<len;i++) out[i]=b[st+i]; return string(out);
    }
}
