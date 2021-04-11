import * as aes from "aes-js";

const rawKey = [13,5,9,14,6,9,4,3,8,2,0,7,9,12,12,8,13,14]
const keyArray: number[] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77];

for (let i = 0; i < 18; i += 2) {
    keyArray[i + 7] = rawKey[i] * 16 + rawKey[i];
}

const key = new Uint8Array(keyArray);
const iv = new Uint8Array([7, 99,  44,  37,  40, 240, 88,  3,  69, 107, 162, 242, 120, 37, 105,  17]);
const plainText = aes.utils.utf8.toBytes("pctf{ok_but_this_is_the_last_one_i_promise_T__T}")

const aesCbc = new aes.ModeOfOperation.cbc(key, iv);

const cypherText = aes.utils.hex.fromBytes(aesCbc.encrypt(plainText));
console.log(cypherText);