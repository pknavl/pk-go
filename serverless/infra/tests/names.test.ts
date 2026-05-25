import { describe, expect, it } from "vitest";
import { tableName } from "../src/components/names";

describe("infra naming", () => {
  it("builds stage-specific table name", () => {
    expect(tableName("pk-go", "dev")).toBe("pk-go-dev");
  });
});
