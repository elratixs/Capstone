import { createHash } from "node:crypto";
import net from "node:net";
import { env } from "../config/env.js";

export function verifyClinicalFile(buffer: Buffer, mimeType: string, expectedSha256: string): boolean {
  if (createHash("sha256").update(buffer).digest("hex") !== expectedSha256) return false;
  if (mimeType === "application/pdf") return buffer.subarray(0, 5).toString("ascii") === "%PDF-";
  if (mimeType === "image/png") return buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
  if (mimeType === "image/jpeg") return buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  if (mimeType === "image/heic") return buffer.subarray(4, 8).toString("ascii") === "ftyp" && ["heic", "heix", "hevc", "hevx", "mif1", "msf1"].includes(buffer.subarray(8, 12).toString("ascii"));
  return false;
}

export async function scanWithClamAv(buffer: Buffer): Promise<boolean> {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection({ host: env.CLAMAV_HOST, port: env.CLAMAV_PORT });
    const chunks: Buffer[] = [];
    let settled = false;
    const finish = (error?: Error, clean?: boolean) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      if (error) reject(error);
      else resolve(Boolean(clean));
    };
    socket.setTimeout(20_000, () => finish(new Error("ClamAV scan timed out.")));
    socket.on("error", (error) => finish(error));
    socket.on("data", (chunk) => {
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      const response = Buffer.concat(chunks).toString("utf8");
      if (response.includes("FOUND")) finish(undefined, false);
      else if (response.includes("OK")) finish(undefined, true);
      else if (response.includes("ERROR")) finish(new Error("ClamAV could not scan the object."));
    });
    socket.on("connect", () => {
      socket.write(Buffer.from("zINSTREAM\0", "utf8"));
      const chunkSize = 64 * 1024;
      for (let offset = 0; offset < buffer.length; offset += chunkSize) {
        const part = buffer.subarray(offset, Math.min(offset + chunkSize, buffer.length));
        const size = Buffer.alloc(4);
        size.writeUInt32BE(part.length);
        socket.write(size);
        socket.write(part);
      }
      socket.write(Buffer.alloc(4));
    });
  });
}
