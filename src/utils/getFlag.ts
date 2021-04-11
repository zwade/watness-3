import * as aes from "aes-js";

export const decode = (rawKey: number[]) => {
    const keyArray: number[] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77];

    for (let i = 0; i < 18; i += 2) {
        keyArray[i + 7] = rawKey[i] * 16 + rawKey[i];
    }

    const key = new Uint8Array(keyArray);
    const iv = new Uint8Array([7, 99,  44,  37,  40, 240, 88,  3,  69, 107, 162, 242, 120, 37, 105,  17]);
    const cypherText = aes.utils.hex.toBytes("d00bdd332962b071daf3bd798cc52c860dc5720bcc3a9f79ff714ec4ba10df504d0d21aec15aa521788da8933b24c970")

    const aesCbc = new aes.ModeOfOperation.cbc(key, iv);

    const plainText = aesCbc.decrypt(cypherText);
    return String.fromCharCode(...plainText);
}