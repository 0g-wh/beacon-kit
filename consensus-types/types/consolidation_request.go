package types

import (
	"fmt"

	"github.com/berachain/beacon-kit/primitives/common"
	"github.com/berachain/beacon-kit/primitives/crypto"
	"github.com/berachain/beacon-kit/primitives/eip7685"
	"github.com/karalabe/ssz"
)

const maxConsolidationRequestsPerPayload = 2
const sszConsolidationRequestSize = 116

// ConsolidationRequest is introduced in Pectra but not used by us.
// We keep it so we can maintain parity tests with other SSZ implementations.
type ConsolidationRequest struct {
	SourceAddress common.ExecutionAddress
	SourcePubKey  crypto.BLSPubkey
	TargetPubKey  crypto.BLSPubkey
}

func (c *ConsolidationRequest) ValidateAfterDecodingSSZ() error {
	return nil
}

// ConsolidationRequests is used for SSZ unmarshalling a list of ConsolidationRequest
type ConsolidationRequests []*ConsolidationRequest

/* -------------------------------------------------------------------------- */
/*                       Consolidation Requests SSZ                           */
/* -------------------------------------------------------------------------- */

func (c *ConsolidationRequest) DefineSSZ(codec *ssz.Codec) {
	ssz.DefineStaticBytes(codec, &c.SourceAddress)
	ssz.DefineStaticBytes(codec, &c.SourcePubKey)
	ssz.DefineStaticBytes(codec, &c.TargetPubKey)
}

func (c *ConsolidationRequest) SizeSSZ(_ *ssz.Sizer) uint32 {
	return sszConsolidationRequestSize
}

func (c *ConsolidationRequest) MarshalSSZ() ([]byte, error) {
	buf := make([]byte, ssz.Size(c))
	return buf, ssz.EncodeToBytes(buf, c)
}

// HashTreeRoot returns the hash tree root of the Deposits.
func (c *ConsolidationRequest) HashTreeRoot() common.Root {
	return ssz.HashSequential(c)
}

// MarshalSSZ marshals the ConsolidationRequests object to SSZ format by encoding each consolidation request individually.
func (cr *ConsolidationRequests) MarshalSSZ() ([]byte, error) {
	return eip7685.MarshalItems[*ConsolidationRequest](*cr)
}

// DecodeConsolidationRequests decodes SSZ data by decoding each request individually.
func DecodeConsolidationRequests(data []byte) (ConsolidationRequests, error) {
	maxSize := maxConsolidationRequestsPerPayload * sszConsolidationRequestSize
	if len(data) > maxSize {
		return nil, fmt.Errorf(
			"invalid consolidation requests SSZ size, requests should not be more than the "+
				"max per payload, got %d max %d", len(data), maxSize,
		)
	}
	requestSize := int(ssz.Size(&ConsolidationRequest{}))
	if len(data) < requestSize {
		return nil, fmt.Errorf(
			"invalid consolidation requests SSZ size, got %d expected at least %d", len(data), requestSize,
		)
	}
	if len(data)%requestSize != 0 {
		return nil, fmt.Errorf(
			"invalid data length: %d is not a multiple of consolidation request size %d", len(data), requestSize,
		)
	}
	items, err := eip7685.UnmarshalItems[*ConsolidationRequest](
		data,
		requestSize,
		func() *ConsolidationRequest { return new(ConsolidationRequest) },
	)
	if err != nil {
		return nil, err
	}
	consolidationRequests := ConsolidationRequests(items)
	return consolidationRequests, nil
}
