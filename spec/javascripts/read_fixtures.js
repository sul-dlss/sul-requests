import fs from 'fs'
import path from 'path'

export default function(filename) {
  return fs.readFileSync(path.resolve(__dirname, 'fixtures', filename), 'utf8')
}
